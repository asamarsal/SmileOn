import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/components/smile_touchable.dart';

/// Komponen Frame Item seragam (Design System)
/// Digunakan pada pemilihan Frame Photobox.
class SmileFrameItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final bool isLandscape;
  final VoidCallback? onTap;

  const SmileFrameItem({
    super.key,
    required this.item,
    required this.isSelected,
    this.isLandscape = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SmileTouchable(
      onTap: onTap,
      enableOpacity: false,
      child: isLandscape ? _buildLandscape() : _buildPortrait(),
    );
  }

  Widget _buildLandscape() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.lightPink : AppTheme.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryRose : Colors.grey.shade200,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryRose.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.image_outlined,
                    size: 48,
                    color: isSelected ? AppTheme.primaryRose : Colors.grey.shade400,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryRose : Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.favorite_border,
                      color: isSelected ? Colors.white : AppTheme.primaryRose,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item['title'] as String,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryRose : AppTheme.text,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPortrait() {
    final bool isPremium = item['type'] == 'Premium';
    
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.lightPink : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryRose : Colors.grey.shade200,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppTheme.primaryRose.withOpacity(0.15)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Image / Photostrip display
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (item['image'] != null || item['imageUrl'] != null || item['imageAsset'] != null)
                        ? Image.asset(
                            (item['image'] ?? item['imageUrl'] ?? item['imageAsset']) as String,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                isSelected ? Icons.check_circle : Icons.broken_image_rounded,
                                size: 40,
                                color: isSelected ? AppTheme.primaryRose : Colors.grey.shade400,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              isSelected ? Icons.check_circle : (item['icon'] as IconData? ?? Icons.image_outlined),
                              size: 48,
                              color: isSelected ? AppTheme.primaryRose : Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),
                // Top right icon
                if (isSelected)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryRose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  )
                else if (item['icon'] != null && item['icon'] != Icons.lock_outline)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryRose,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'] as IconData, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item['title'] as String,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryRose : AppTheme.text,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (isPremium)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.pinkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Premium', style: TextStyle(color: AppTheme.primaryRose, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        else
          const Text('Gratis', style: TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
