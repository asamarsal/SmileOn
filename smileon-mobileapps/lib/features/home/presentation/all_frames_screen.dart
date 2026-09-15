import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/components/smile_chooseframe_vertical.dart';
import 'package:smileon/core/components/smile_chooseframe_horizontal.dart';

class AllFramesScreen extends StatelessWidget {
  const AllFramesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: isPortrait
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Pilih Frame',
                style: TextStyle(
                  color: AppTheme.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRose),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: isPortrait
            ? const SmileChooseframeVertical()
            : const SmileChooseframeHorizontal(),
      ),
    );
  }
}
