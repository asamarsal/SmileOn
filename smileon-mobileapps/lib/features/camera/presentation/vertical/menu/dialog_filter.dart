import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilterDialog extends StatefulWidget {
  final int initialFilterIndex;
  final ValueChanged<int> onFilterSelected;

  const FilterDialog({
    super.key,
    required this.initialFilterIndex,
    required this.onFilterSelected,
  });

  static void show(
    BuildContext context, {
    required int initialFilterIndex,
    required ValueChanged<int> onFilterSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => FilterDialog(
        initialFilterIndex: initialFilterIndex,
        onFilterSelected: onFilterSelected,
      ),
    );
  }

  static final List<Map<String, dynamic>> filters = [
    {
      'name': 'Original',
      'matrix': [
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Natural',
      'matrix': [
        1.1, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.05, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Bright',
      'matrix': [
        1.2, 0.0, 0.0, 0.0, 10.0,
        0.0, 1.2, 0.0, 0.0, 10.0,
        0.0, 0.0, 1.2, 0.0, 10.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Warm',
      'matrix': [
        1.1, 0.0, 0.0, 0.0, 15.0,
        0.0, 1.0, 0.0, 0.0, 5.0,
        0.0, 0.0, 0.9, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Cool',
      'matrix': [
        0.9, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 5.0,
        0.0, 0.0, 1.1, 0.0, 15.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Fade',
      'matrix': [
        0.8, 0.0, 0.0, 0.0, 20.0,
        0.0, 0.8, 0.0, 0.0, 20.0,
        0.0, 0.0, 0.8, 0.0, 20.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Mono',
      'matrix': [
        0.33, 0.59, 0.11, 0.0, 0.0,
        0.33, 0.59, 0.11, 0.0, 0.0,
        0.33, 0.59, 0.11, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Noir',
      'matrix': [
        0.33, 0.59, 0.11, 0.0, -20.0,
        0.33, 0.59, 0.11, 0.0, -20.0,
        0.33, 0.59, 0.11, 0.0, -20.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Vintage',
      'matrix': [
        0.9, 0.5, 0.1, 0.0, 0.0,
        0.3, 0.8, 0.1, 0.0, 0.0,
        0.2, 0.3, 0.5, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Sepia',
      'matrix': [
        0.393, 0.769, 0.189, 0.0, 0.0,
        0.349, 0.686, 0.168, 0.0, 0.0,
        0.272, 0.534, 0.131, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Orange Teal',
      'matrix': [
        1.2, -0.2, -0.2, 0.0, 10.0,
        -0.2, 1.0, 0.2, 0.0, 0.0,
        -0.2, -0.2, 1.2, 0.0, 10.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
    {
      'name': 'Pastel',
      'matrix': [
        0.8, 0.1, 0.1, 0.0, 20.0,
        0.1, 0.8, 0.1, 0.0, 20.0,
        0.1, 0.1, 0.8, 0.0, 20.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    },
  ];

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  int _selectedCategoryIndex = 0;
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedFilterIndex = widget.initialFilterIndex;
  }

  final List<String> _categories = ['Semua', 'Estetik', 'Warna', 'Film'];

  static final List<Map<String, dynamic>> filters = [
    {
      'name': 'Original',
      'matrix': [
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'Natural',
      'matrix': [
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.05,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'Bright',
      'matrix': [
        1.1,
        0.0,
        0.0,
        0.0,
        15.0,
        0.0,
        1.1,
        0.0,
        0.0,
        15.0,
        0.0,
        0.0,
        1.1,
        0.0,
        15.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'Warm',
      'matrix': [
        1.2,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.1,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.8,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'Cool',
      'matrix': [
        0.8,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.9,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.2,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'Vivid',
      'matrix': [
        1.3,
        -0.1,
        -0.1,
        0.0,
        0.0,
        -0.1,
        1.3,
        -0.1,
        0.0,
        0.0,
        -0.1,
        -0.1,
        1.3,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'B&W',
      'matrix': [
        0.2126,
        0.7152,
        0.0722,
        0.0,
        0.0,
        0.2126,
        0.7152,
        0.0722,
        0.0,
        0.0,
        0.2126,
        0.7152,
        0.0722,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'Vintage',
      'matrix': [
        0.9,
        0.5,
        0.1,
        0.0,
        0.0,
        0.3,
        0.8,
        0.1,
        0.0,
        0.0,
        0.2,
        0.3,
        0.5,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER (Title and Close Button)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(
                    color: Color(0xFF1E1E22),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF1E1E22),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // TABS (Semua, Estetik, Warna, Film)
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // FILTER GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // Adjust for image + text
              ),
              itemCount: FilterDialog.filters.length,
              itemBuilder: (context, index) {
                final filter = FilterDialog.filters[index];
                final isSelected = _selectedFilterIndex == index;
                final filterMatrix = filter['matrix'] as List<double>;
                final filterName = filter['name'] as String;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedFilterIndex = index;
                    });
                    widget.onFilterSelected(index);
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFF43F5E)
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              13,
                            ), // slightly smaller to fit inside border
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(filterMatrix),
                              child: Image.asset(
                                'assets/images/hero/couple_photos_horizontal_1.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        filterName,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFF43F5E)
                              : const Color(0xFF1E1E22),
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
