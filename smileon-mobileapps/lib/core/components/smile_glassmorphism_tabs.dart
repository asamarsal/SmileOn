import 'dart:ui';
import 'package:flutter/material.dart';

/// Model item untuk SmileGlassmorphismTabs
class GlassmorphismTabItem {
  final String label;
  final IconData icon;

  const GlassmorphismTabItem({
    required this.label,
    required this.icon,
  });
}

/// Komponen Tab Bar Glassmorphism mengambang (floating capsule)
/// Sesuai dengan desain mockup kamera SmileOn
class SmileGlassmorphismTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<GlassmorphismTabItem> tabs;
  final double height;
  final EdgeInsetsGeometry padding;

  const SmileGlassmorphismTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.tabs = const [
      GlassmorphismTabItem(
        label: 'Event',
        icon: Icons.calendar_today_outlined,
      ),
      GlassmorphismTabItem(
        label: 'Personal',
        icon: Icons.person_rounded,
      ),
    ],
    this.height = 56.0,
    this.padding = const EdgeInsets.all(5.0),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity;
        if (velocity != null) {
          if (velocity < -120 && selectedIndex < tabs.length - 1) {
            onTabSelected(selectedIndex + 1);
          } else if (velocity > 120 && selectedIndex > 0) {
            onTabSelected(selectedIndex - 1);
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++) ...[
                  Expanded(
                    child: _buildTabItem(i),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = selectedIndex == index;
    final tab = tabs[index];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFF2D78),
                    Color(0xFFFF488E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF2D78).withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              tab.icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.9),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
