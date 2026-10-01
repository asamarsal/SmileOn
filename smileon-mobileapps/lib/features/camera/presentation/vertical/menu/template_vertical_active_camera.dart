import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/presentation/vertical/chooseframe_dialog.dart';

class TemplateVerticalActiveCamera extends StatelessWidget {
  final int selectedFrameIndex;
  final ValueChanged<int> onFrameSelected;

  const TemplateVerticalActiveCamera({
    super.key,
    required this.selectedFrameIndex,
    required this.onFrameSelected,
  });

  void _showAllFramesDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    ChooseFrameDialog.show(
      context: context,
      initialSelectedIndex: selectedFrameIndex,
      onFrameSelected: onFrameSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header di atas kanan frame: Teks "Lihat Semua"
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Frame',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E32),
                  letterSpacing: 0.2,
                ),
              ),
              GestureDetector(
                onTap: () => _showAllFramesDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRose.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryRose.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRose,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10.5,
                        color: AppTheme.primaryRose,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // Tepat 3 1/2 frame yang muncul di viewport horizontal agar proporsional dan lebih tinggi
            final double itemWidth = math.max(
              86.0,
              (constraints.maxWidth - (3 * 10.0)) / 3.5,
            );
            // Rasio photostrip 1:3 (600x1800 px)
            final double carouselHeight = itemWidth * 3.0;

            return SizedBox(
              height: carouselHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  for (
                    int i = 0;
                    i < VerticalFrameThumbnails.allFrames.length;
                    i++
                  )
                    _buildFrameCardItem(
                      i,
                      VerticalFrameThumbnails.buildThumbnail(i),
                      width: itemWidth,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFrameCardItem(
    int index,
    Widget frameContent, {
    double width = 86,
  }) {
    final isSelected = selectedFrameIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onFrameSelected(index);
      },
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRose : Colors.transparent,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryRose.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 13.5 : 15),
          child: frameContent,
        ),
      ),
    );
  }
}
