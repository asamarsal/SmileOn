import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/activity/presentation/components/eventattended_slider.dart';

/// Halaman Kategori Detail: Semua Event yang Diikuti
class EventAttendedActivityScreen extends ConsumerWidget {
  const EventAttendedActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        centerTitle: true,
        title: Text(
          t.joinedEvents,
          style: const TextStyle(
            color: Color(0xFF1E1E22),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRose),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: EventAttendedSlider(
            isExpanded: true,
            showHeader: false,
          ),
        ),
      ),
    );
  }
}
